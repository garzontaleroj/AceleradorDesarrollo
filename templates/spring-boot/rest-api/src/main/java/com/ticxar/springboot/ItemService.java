package com.ticxar.springboot;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.stereotype.Service;

@Service
public class ItemService {

    private final List<Item> items = new CopyOnWriteArrayList<>();
    private final AtomicLong idSequence = new AtomicLong(0);

    public ItemService() {
        create(new Item(null, "Item 1", "Primer item de ejemplo"));
        create(new Item(null, "Item 2", "Segundo item de ejemplo"));
    }

    public List<Item> listAll() {
        return new ArrayList<>(items);
    }

    public Optional<Item> findById(Long id) {
        return items.stream()
                .filter(item -> item.getId().equals(id))
                .findFirst();
    }

    public Item create(Item item) {
        item.setId(idSequence.incrementAndGet());
        items.add(item);
        return item;
    }

    public Optional<Item> update(Long id, Item updated) {
        for (int i = 0; i < items.size(); i++) {
            if (items.get(i).getId().equals(id)) {
                updated.setId(id);
                items.set(i, updated);
                return Optional.of(updated);
            }
        }
        return Optional.empty();
    }

    public boolean delete(Long id) {
        return items.removeIf(item -> item.getId().equals(id));
    }
}
