
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS distinct_cast_count,
        LISTAGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') WITHIN GROUP (ORDER BY a.name) AS cast_members
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
), 
MovieInfoWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.info,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_info m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.note IS NULL
), 
CompletedMovieInfo AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        cd.distinct_cast_count,
        cd.cast_members,
        COALESCE(miwk.info, 'No info available') AS info,
        COALESCE(miwk.keyword, 'No keywords') AS keywords
    FROM 
        RankedTitles mt
    LEFT JOIN 
        CastDetails cd ON mt.title_id = cd.movie_id
    LEFT JOIN 
        MovieInfoWithKeywords miwk ON mt.title_id = miwk.movie_id
    WHERE 
        mt.rank <= 5 
)
SELECT 
    c.title,
    c.production_year,
    c.distinct_cast_count,
    c.cast_members,
    c.info,
    CASE 
        WHEN c.keywords IS NOT NULL THEN c.keywords
        ELSE 'None'
    END AS keywords
FROM 
    CompletedMovieInfo c
WHERE 
    c.production_year > 2000
ORDER BY 
    c.production_year DESC, c.title;
