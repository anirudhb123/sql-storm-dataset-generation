WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
),
CastMembers AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        STRING_AGG(DISTINCT na.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
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
    rt.title,
    rt.production_year,
    cm.num_cast,
    cm.cast_names,
    mk.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    CastMembers cm ON rt.title_id = cm.movie_id
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title ASC;

This SQL query benchmarks string processing in the context of a movie database. It generates a ranking of movie titles based on their production year and counts the number of distinct cast members, compiling their names into a string. Additionally, it collects all keywords associated with each movie and outputs the top 5 titles per production year, organized in descending order of the year and ascending order of the title.
