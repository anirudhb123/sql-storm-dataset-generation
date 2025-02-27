WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) as rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count, 
        STRING_AGG(a.name, ', ') AS actor_names
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
MovieCompaniesDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    rt.title AS Movie_Title, 
    rt.production_year AS Release_Year, 
    cd.cast_count AS Number_of_Actors, 
    cd.actor_names AS Actors, 
    mcd.company_names AS Production_Companies,
    mk.keywords AS Movie_Keywords
FROM RankedTitles rt
LEFT JOIN CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN MovieCompaniesDetails mcd ON rt.title_id = mcd.movie_id
LEFT JOIN MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE rt.rank <= 5
ORDER BY rt.production_year DESC;
