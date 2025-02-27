WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL 
)
SELECT 
    r.aka_name,
    COUNT(DISTINCT r.title_id) AS title_count,
    STRING_AGG(DISTINCT r.title, ', ') AS titles,
    MIN(r.production_year) AS earliest_year,
    MAX(r.production_year) AS latest_year
FROM 
    RankedTitles r
WHERE 
    r.rank <= 5
GROUP BY 
    r.aka_name
ORDER BY 
    title_count DESC, earliest_year ASC;

This SQL query benchmarks string processing by generating a list of people (via their 'aka_name') along with several aggregations:

1. It counts the distinct titles associated with each alias.
2. It creates a string of these titles, concatenated together.
3. It calculates the earliest and latest production year of the titles linked to each alias.
4. It filters to only include the top 5 recent titles per person.

The end result is a comprehensive view of how many titles each person has been associated with, along with the specifics of those titles, which could be useful for performance testing in string processing across multiple joins and aggregations.
