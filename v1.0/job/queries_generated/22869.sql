WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5 -- top 5 movies by cast count for each production year
),

TopKeywordMovies AS (
    SELECT 
        fk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword fk
    JOIN 
        keyword k ON fk.keyword_id = k.id
    WHERE 
        k.phonetic_code IS NOT NULL
    GROUP BY 
        fk.movie_id
),

FullMovieInfo AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.cast_count,
        COALESCE(tkm.keywords, 'No keywords') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        TopKeywordMovies tkm ON fm.movie_id = tkm.movie_id
),

PersonDetails AS (
    SELECT 
        p.person_id,
        a.name,
        pi.info AS bio,
        ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY pi.info_type_id) AS row_num
    FROM 
        aka_name a
    JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        pi.info_type_id IS NOT NULL
)

SELECT 
    fmi.title,
    fmi.production_year,
    fmi.cast_count,
    fmi.keywords,
    STRING_AGG(DISTINCT pd.name, ', ') AS actor_names,
    SUM(CASE WHEN pd.row_num = 1 THEN 1 ELSE 0 END) AS primary_bios_count,
    MAX(CASE WHEN pd.row_num = 1 THEN pd.bio ELSE NULL END) AS primary_bio,
    CASE 
        WHEN fmi.cast_count < 5 THEN 'Fewer than 5 actors'
        ELSE '5 or more actors'
    END AS cast_size_info
FROM 
    FullMovieInfo fmi
LEFT JOIN 
    PersonDetails pd ON fmi.movie_id = pd.person_id
GROUP BY 
    fmi.movie_id, fmi.title, fmi.production_year, fmi.cast_count, fmi.keywords
ORDER BY 
    fmi.production_year DESC, fmi.cast_count DESC;
