WITH RankedTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        a.imdb_index,
        a.phonetic_code,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
), 
Actors AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
), 
KeywordLinks AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    t.kind_id,
    a.actor_count,
    a.actor_names,
    kl.keywords
FROM 
    RankedTitles t
LEFT JOIN 
    Actors a ON t.title_id = a.movie_id
LEFT JOIN 
    KeywordLinks kl ON t.title_id = kl.movie_id
WHERE 
    t.rank <= 5
ORDER BY 
    t.kind_id, 
    t.production_year DESC;

This query retrieves the top 5 most recent titles for each kind of movie, along with the number of unique actors and a list of keywords associated with each title. The use of Common Table Expressions (CTEs) enhances the readability and modularity of the query, enabling complex aggregations and ranking operations.
