CC = gcc
CFLAGS = -Wall -Wextra -I./include
SRCS = src/main.c src/parser.c src/exporter.c src/prereq_checker.c src/schedule_checker.c src/validator.c
TARGET = cemestre_c
all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET)