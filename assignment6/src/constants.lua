VIRTUAL_WIDTH = 640
VIRTUAL_HEIGHT = 360

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

MAP_SCROLL_X_SPEED = 100
BACKGROUND_SCROLL_X_SPEED = MAP_SCROLL_X_SPEED / 2

TILE_SIZE = 35
ALIEN_SIZE = TILE_SIZE

DEGREES_TO_RADIANS = 0.0174532925199432957
RADIANS_TO_DEGREES = 57.295779513082320876

-- categories for box2d fixtures (used in setCategory / getCategory), up to 16 categories allowed
NORMAL = 1  -- default for all fixtures (including splittable player aliens, i.e. not collided w/ anything nor split yet)
UNSPLITTABLE = 2  -- used for unsplittable player aliens (i.e. has collided w/ something or already split)