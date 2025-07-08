
WITH RankedMovies AS (
    SELECT
        a.title AS movie_title,
        c.name AS cast_member,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank,
        COALESCE(mi.info, 'No description available') AS movie_description
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Description')
    WHERE
        a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT
        movie_title,
        cast_member,
        movie_description
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
UniqueDescriptions AS (
    SELECT 
        DISTINCT movie_description
    FROM 
        FilteredMovies
    WHERE 
        movie_description IS NOT NULL
)

SELECT 
    fm.movie_title,
    fm.cast_member,
    COUNT(ud.movie_description) AS description_count,
    LISTAGG(ud.movie_description, '; ') WITHIN GROUP (ORDER BY ud.movie_description) AS all_descriptions
FROM 
    FilteredMovies fm
LEFT JOIN 
    UniqueDescriptions ud ON fm.movie_description = ud.movie_description
GROUP BY 
    fm.movie_title, fm.cast_member
ORDER BY 
    fm.movie_title, fm.cast_member;
