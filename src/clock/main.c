#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <SDL/SDL_ttf.h>

#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 240

#define RES_PATH "/mnt/SDCARD/System/res/"

enum {
	TRIMUI_A = SDLK_SPACE,
	TRIMUI_B = SDLK_LCTRL,
};

enum {
	FIELD_YEAR,
	FIELD_MONTH,
	FIELD_DAY,
	FIELD_HOUR,
	FIELD_MINUTE,
	FIELD_SECOND,
	FIELD_COUNT,
};

typedef struct {
	int year;
	int month;
	int day;
	int hour;
	int minute;
	int second;
} ClockTime;

static int daysInMonth(int year, int month) {
	static const int days[] = {
		31, 28, 31, 30, 31, 30,
		31, 31, 30, 31, 30, 31,
	};

	if (month == 2) {
		int leap = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
		return leap ? 29 : 28;
	}

	return days[month - 1];
}

static void validate(ClockTime* clock) {
	if (clock->year < 1970) clock->year = 1970;
	if (clock->year > 2100) clock->year = 2100;

	if (clock->month < 1) clock->month = 12;
	if (clock->month > 12) clock->month = 1;

	int max_day = daysInMonth(clock->year, clock->month);

	if (clock->day < 1) clock->day = max_day;
	if (clock->day > max_day) clock->day = 1;

	if (clock->hour < 0) clock->hour = 23;
	if (clock->hour > 23) clock->hour = 0;

	if (clock->minute < 0) clock->minute = 59;
	if (clock->minute > 59) clock->minute = 0;

	if (clock->second < 0) clock->second = 59;
	if (clock->second > 59) clock->second = 0;
}

static void adjust(ClockTime* clock, int field, int amount) {
	switch (field) {
		case FIELD_YEAR:
			clock->year += amount;
			break;
		case FIELD_MONTH:
			clock->month += amount;
			break;
		case FIELD_DAY:
			clock->day += amount;
			break;
		case FIELD_HOUR:
			clock->hour += amount;
			break;
		case FIELD_MINUTE:
			clock->minute += amount;
			break;
		case FIELD_SECOND:
			clock->second += amount;
			break;
	}

	validate(clock);
}

static int textWidth(TTF_Font* font, const char* text) {
	int width = 0;
	TTF_SizeUTF8(font, text, &width, NULL);
	return width;
}

static int drawText(
	SDL_Surface* screen,
	TTF_Font* font,
	const char* text,
	int x,
	int y,
	SDL_Color color
) {
	SDL_Surface* surface = TTF_RenderUTF8_Blended(font, text, color);

	if (!surface) return x;

	SDL_BlitSurface(surface, NULL, screen, &(SDL_Rect){x, y, 0, 0});

	int width = surface->w;
	SDL_FreeSurface(surface);

	return x + width;
}

static void drawClock(
	SDL_Surface* screen,
	TTF_Font* font,
	TTF_Font* small,
	TTF_Font* button_font,
	SDL_Surface* title_bar,
	SDL_Surface* bottom_bar,
	SDL_Surface* round_button,
	const ClockTime* clock,
	int selected
) {
	SDL_Color white = {0xff, 0xff, 0xff};
	SDL_Color gold = {0xd2, 0xb4, 0x6c};

	SDL_FillRect(screen, NULL, 0);

	if (title_bar) {
		SDL_BlitSurface(title_bar, NULL, screen, NULL);
	}

	if (bottom_bar) {
		SDL_BlitSurface(bottom_bar, NULL, screen, &(SDL_Rect){0, 202, 0, 0});
	}

	const char* title = "DATE & TIME";
	int title_width = textWidth(font, title);
	drawText(screen, font, title, (SCREEN_WIDTH - title_width) / 2, 8, white);

	char fields[FIELD_COUNT][8];

	snprintf(fields[FIELD_YEAR], sizeof(fields[FIELD_YEAR]), "%04d", clock->year);
	snprintf(fields[FIELD_MONTH], sizeof(fields[FIELD_MONTH]), "%02d", clock->month);
	snprintf(fields[FIELD_DAY], sizeof(fields[FIELD_DAY]), "%02d", clock->day);
	snprintf(fields[FIELD_HOUR], sizeof(fields[FIELD_HOUR]), "%02d", clock->hour);
	snprintf(fields[FIELD_MINUTE], sizeof(fields[FIELD_MINUTE]), "%02d", clock->minute);
	snprintf(fields[FIELD_SECOND], sizeof(fields[FIELD_SECOND]), "%02d", clock->second);

	const char* separators[] = {
		"/",
		"/",
		"   ",
		":",
		":",
	};

	int total_width = 0;

	for (int i = 0; i < FIELD_COUNT; i++) {
		total_width += textWidth(font, fields[i]);

		if (i < FIELD_COUNT - 1) {
			total_width += textWidth(font, separators[i]);
		}
	}

	int x = (SCREEN_WIDTH - total_width) / 2;
	int y = 104;

	for (int i = 0; i < FIELD_COUNT; i++) {
		int field_x = x;
		int field_width = textWidth(font, fields[i]);

		x = drawText(
			screen,
			font,
			fields[i],
			x,
			y,
			i == selected ? gold : white
		);

		if (i == selected) {
			uint32_t color = SDL_MapRGB(
				screen->format,
				gold.r,
				gold.g,
				gold.b
			);

			SDL_FillRect(
				screen,
				&(SDL_Rect){field_x, y + 29, field_width, 2},
				color
			);
		}

		if (i < FIELD_COUNT - 1) {
			x = drawText(screen, font, separators[i], x, y, white);
		}
	}

	SDL_Color button_gold = {0x9f, 0x89, 0x52};

	// B Cancel
	SDL_BlitSurface(
		round_button,
		NULL,
		screen,
		&(SDL_Rect){10, 210, 0, 0}
	);

	drawText(
		screen,
		button_font,
		"B",
		17,
		211,
		button_gold
	);

	drawText(
		screen,
		small,
		"CANCEL",
		35,
		212,
		white
	);

	// A Save
	SDL_BlitSurface(
		round_button,
		NULL,
		screen,
		&(SDL_Rect){251, 210, 0, 0}
	);

	drawText(
		screen,
		button_font,
		"A",
		257,
		211,
		button_gold
	);

	drawText(
		screen,
		small,
		"SAVE",
		276,
		212,
		white
	);

	SDL_Flip(screen);
}

static void setSystemTime(const ClockTime* clock) {
	struct tm value = {0};

	value.tm_year = clock->year - 1900;
	value.tm_mon = clock->month - 1;
	value.tm_mday = clock->day;
	value.tm_hour = clock->hour;
	value.tm_min = clock->minute;
	value.tm_sec = clock->second;
	value.tm_isdst = -1;

	time_t timestamp = mktime(&value);

	if (timestamp == (time_t)-1) return;

	char command[64];

	snprintf(
		command,
		sizeof(command),
		"date -s \"@%ld\" >/dev/null",
		(long)timestamp
	);

	system(command);
}

int main(void) {
	if (SDL_Init(SDL_INIT_VIDEO) == -1) {
		puts(SDL_GetError());
		return EXIT_FAILURE;
	}

	if (TTF_Init() == -1) {
		puts(TTF_GetError());
		SDL_Quit();
		return EXIT_FAILURE;
	}

	SDL_Surface* screen = SDL_SetVideoMode(
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
		16,
		SDL_SWSURFACE
	);

	if (!screen) {
		puts(SDL_GetError());
		TTF_Quit();
		SDL_Quit();
		return EXIT_FAILURE;
	}

	SDL_ShowCursor(0);
	SDL_EnableKeyRepeat(300, 100);

	TTF_Font* font = TTF_OpenFont(RES_PATH "BPreplayBold.otf", 24);
	TTF_Font* small = TTF_OpenFont(RES_PATH "BPreplayBold.otf", 14);
	TTF_Font* button_font = TTF_OpenFont(RES_PATH "BPreplayBold.otf", 16);

	SDL_Surface* title_bar = IMG_Load(RES_PATH "title-bg.png");
	SDL_Surface* bottom_bar = IMG_Load(RES_PATH "tips-bar-bg.png");
	SDL_Surface* round_button = IMG_Load(RES_PATH "nav-bar-item-bg.png");

	if (!font || !small || !button_font) {
		puts(TTF_GetError());
		return EXIT_FAILURE;
	}

	time_t now = time(NULL);
	struct tm* current = localtime(&now);

	ClockTime clock = {
		.year = current->tm_year + 1900,
		.month = current->tm_mon + 1,
		.day = current->tm_mday,
		.hour = current->tm_hour,
		.minute = current->tm_min,
		.second = current->tm_sec,
	};

	int selected = FIELD_YEAR;
	int quit = 0;
	int save = 0;
	int dirty = 1;

	SDL_Event event;

	while (!quit) {
		while (SDL_PollEvent(&event)) {
			if (event.type != SDL_KEYDOWN) continue;

			switch (event.key.keysym.sym) {
				case SDLK_LEFT:
					selected--;
					if (selected < 0) selected = FIELD_COUNT - 1;
					dirty = 1;
					break;

				case SDLK_RIGHT:
					selected++;
					if (selected >= FIELD_COUNT) selected = 0;
					dirty = 1;
					break;

				case SDLK_UP:
					adjust(&clock, selected, 1);
					dirty = 1;
					break;

				case SDLK_DOWN:
					adjust(&clock, selected, -1);
					dirty = 1;
					break;

				case TRIMUI_A:
					save = 1;
					quit = 1;
					break;

				case TRIMUI_B:
					quit = 1;
					break;

				default:
					break;
			}
		}

		if (dirty) {
			drawClock(
				screen,
				font,
				small,
				button_font,
				title_bar,
				bottom_bar,
				round_button,
				&clock,
				selected
			);

			dirty = 0;
		}

		SDL_Delay(10);
	}

	if (save) {
		setSystemTime(&clock);
	}

	SDL_FreeSurface(title_bar);
	SDL_FreeSurface(bottom_bar);
	SDL_FreeSurface(round_button);

	TTF_CloseFont(font);
	TTF_CloseFont(small);
	TTF_CloseFont(button_font);

	TTF_Quit();
	SDL_Quit();

	return EXIT_SUCCESS;
}
