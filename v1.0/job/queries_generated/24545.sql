WITH MovieCharacter AS (
    SELECT 
        c.movie_id,
        a.name AS character_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS char_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.character_name) AS num_characters,
        string_agg(DISTINCT a.md5sum, ', ') AS aggregated_md5s
    FROM 
        aka_title m
    LEFT JOIN 
        MovieCharacter mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Description'
        )
    LEFT JOIN 
        aka_name a ON mc.character_name = a.name
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT mc.character_name) > 3 -- movies with more than 3 different characters
),
CharRanking AS (
    SELECT 
        movie_id,
        character_name,
        char_rank,
        RANK() OVER (PARTITION BY movie_id ORDER BY char_rank) AS rank_within_movie
    FROM 
        MovieCharacter
)
SELECT 
    md.title,
    md.production_year,
    md.num_characters,
    md.aggregated_md5s,
    cr.character_name,
    cr.rank_within_movie,
    CASE 
        WHEN cr.rank_within_movie IS NULL THEN 'Unknown Rank'
        ELSE 'Ranked'
    END AS rank_status
FROM 
    MovieDetails md
LEFT JOIN 
    CharRanking cr ON md.movie_id = cr.movie_id
WHERE 
    md.production_year IS NOT NULL
    AND (md.num_characters IS NOT NULL OR md.aggregated_md5s IS NOT NULL)
ORDER BY 
    md.production_year DESC, md.num_characters ASC;
