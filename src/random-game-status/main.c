// Minimal progress screen for Random Game.pak on the Trimui Model S.
// The parent shell script sends one system name per line over stdin.
#include <stdio.h>
#include <string.h>

#include <SDL/SDL.h>
#include <SDL/SDL_ttf.h>

#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 240
#define FONT_PATH "/mnt/SDCARD/System/res/BPreplayBold.otf"

static void drawText(SDL_Surface* screen, TTF_Font* font, const char* label,
    SDL_Color color, int y) {
    SDL_Surface* text = TTF_RenderUTF8_Blended(font, label, color);
    if (!text) return;

    // Limit long system aliases to the screen without allocating more memory.
    SDL_Rect source = {0, 0, text->w > 300 ? 300 : text->w, text->h};
    SDL_Rect dest = {(SCREEN_WIDTH - source.w) / 2, y, 0, 0};
    SDL_BlitSurface(text, &source, screen, &dest);
    SDL_FreeSurface(text);
}

int main(void) {
    if (SDL_Init(SDL_INIT_VIDEO) != 0) return 1;
    if (TTF_Init() != 0) {
        SDL_Quit();
        return 1;
    }

    SDL_Surface* screen = SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, 16, SDL_SWSURFACE);
    TTF_Font* font = TTF_OpenFont(FONT_PATH, 16);
    TTF_Font* small = TTF_OpenFont(FONT_PATH, 14);
    if (!screen || !font || !small) {
        if (font) TTF_CloseFont(font);
        if (small) TTF_CloseFont(small);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }
    SDL_ShowCursor(SDL_DISABLE);

    const SDL_Color white = {255, 255, 255, 0};
    const SDL_Color gold = {210, 180, 108, 0};
    char system[256];
    while (fgets(system, sizeof(system), stdin)) {
        system[strcspn(system, "\r\n")] = '\0';
        SDL_FillRect(screen, NULL, 0); // Solid black, like the PicoArch loading screen.
        drawText(screen, font, "RANDOM GAME", white, 82);
        drawText(screen, small,
            strcmp(system, "Selecting a system...") == 0 ? "Preparing" : "Searching in",
            gold, 119);
        drawText(screen, font, system, white, 145);
        SDL_Flip(screen);
    }

    TTF_CloseFont(small);
    TTF_CloseFont(font);
    TTF_Quit();
    SDL_Quit();
    return 0;
}
