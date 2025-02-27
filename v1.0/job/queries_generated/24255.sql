WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.id AS cast_id, 
        p.name AS person_name, 
        r.role AS person_role, 
        t.title AS movie_title, 
        COALESCE(at.note, 'No Note') AS note_status
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre LIMIT')
    LEFT JOIN 
        aka_title at ON at.movie_id = t.id
),
FilteredGenres AS (
    SELECT 
        DISTINCT mi.movie_id,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Genre', 'Directed By'))
    GROUP BY 
        mi.movie_id
),
FinalOutput AS (
    SELECT 
        rt.title,
        rt.production_year,
        cd.person_name,
        cd.person_role,
        fg.genres,
        AVG(length(t.title)) OVER () AS avg_title_length
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CastDetails cd ON rt.title_id = cd.movie_title
    LEFT JOIN 
        FilteredGenres fg ON rt.title_id = fg.movie_id
    WHERE 
        rt.rank <= 3 AND 
        (cd.note_status IS NOT NULL OR rt.production_year >= 2000)
)
SELECT 
    title,
    production_year,
    person_name,
    person_role,
    COALESCE(genres, 'Unknown Genres') AS genres,
    avg_title_length
FROM 
    FinalOutput
WHERE 
    production_year > (SELECT AVG(production_year) FROM title)
ORDER BY 
    production_year DESC, 
    person_name ASC
LIMIT 100;
