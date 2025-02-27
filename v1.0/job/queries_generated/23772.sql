WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(tc.id) AS title_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(tc.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        comp_cast_type cct ON (cct.id = t.kind_id OR cct.id IS NULL)
    LEFT JOIN 
        cast_info tc ON t.id = tc.movie_id
    GROUP BY t.id, t.title, t.production_year
),

ActiveDirectors AS (
    SELECT 
        c.person_id,
        c.movie_id,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS director_order
    FROM 
        cast_info c
    JOIN 
        role_type rt ON rt.id = c.role_id
    WHERE 
        rt.role = 'Director'
),

DirectorMovies AS (
    SELECT 
        d.person_id,
        COUNT(dm.movie_id) AS movie_count
    FROM 
        ActiveDirectors d
    JOIN 
        complete_cast cm ON d.movie_id = cm.movie_id
    JOIN 
        aka_title tt ON cm.movie_id = tt.id
    GROUP BY 
        d.person_id
),

FinalSelection AS (
    SELECT 
        AK.id AS aka_id,
        AK.name,
        RT.title,
        CASE 
            WHEN RT.production_year IS NULL THEN 'Unknown Year' 
            ELSE CAST(RT.production_year AS TEXT) 
        END AS production_year,
        DM.movie_count
    FROM 
        aka_name AK
    JOIN 
        cast_info CI ON AK.person_id = CI.person_id
    LEFT JOIN 
        RankedTitles RT ON CI.movie_id = RT.id AND RT.rn = 1
    LEFT JOIN 
        DirectorMovies DM ON AK.person_id = DM.person_id
    WHERE 
        AK.name IS NOT NULL OR DM.movie_count > 0
)

SELECT 
    DISTINCT on (fs.aka_id) 
    fs.name, 
    fs.title, 
    fs.production_year,
    COALESCE(fs.movie_count, 0) AS total_movies,
    INITCAP(fs.title) AS capitalized_title,
    LENGTH(TRIM(fs.name)) AS name_length,
    CASE 
        WHEN fs.movie_count IS NULL THEN 'No movies directed'
        ELSE 'Directed ' || fs.movie_count || ' movie(s)'
    END AS director_status   
FROM 
    FinalSelection fs
WHERE 
    (UPPER(fs.name) LIKE 'A%' OR fs.production_year > 2000)
ORDER BY 
    fs.aka_id, fs.total_movies DESC NULLS LAST;
