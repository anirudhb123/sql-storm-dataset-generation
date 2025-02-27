WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        num_cast_members,
        cast_names
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
)
SELECT 
    tt.title,
    tt.production_year,
    tt.num_cast_members,
    tm.kind AS movie_kind,
    tm.info AS more_info
FROM 
    TopRankedTitles tt
JOIN 
    title tm ON tt.title_id = tm.id
LEFT JOIN 
    movie_info mi ON tt.title_id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Description')
ORDER BY 
    tt.production_year DESC, 
    tt.num_cast_members DESC;

This query generates a benchmark of string processing capabilities by first identifying the top 5 movies from each production year based on the number of distinct cast members, then joining this result with related movie types and descriptive information. The final output includes the title, production year, the number of cast members, the kind of movie, and a description where available, sorted by production year and cast size.
