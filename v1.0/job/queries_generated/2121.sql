WITH RecursiveTitle AS (
    SELECT 
        t.id, 
        t.title, 
        t.production_year, 
        ct.kind AS title_kind
    FROM 
        title t
    JOIN 
        kind_type ct ON t.kind_id = ct.id
    WHERE 
        t.production_year IS NOT NULL
),
RankedMovies AS (
    SELECT 
        rt.id, 
        rt.title, 
        rt.production_year, 
        ROW_NUMBER() OVER (PARTITION BY rt.production_year ORDER BY rt.title) AS rank
    FROM 
        RecursiveTitle rt
),
PersonDetails AS (
    SELECT 
        a.name AS actor_name, 
        GROUP_CONCAT(DISTINCT c.movie_id) AS movie_ids
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id
),
KeywordUsage AS (
    SELECT 
        mk.movie_id, 
        k.keyword 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
),
ValidMovies AS (
    SELECT 
        rm.id AS movie_id, 
        rm.title, 
        pd.actor_name, 
        ku.keyword 
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PersonDetails pd ON rm.id IN (SELECT DISTINCT movie_id FROM cast_info WHERE person_role_id IS NOT NULL)
    LEFT JOIN 
        KeywordUsage ku ON rm.id = ku.movie_id
    WHERE 
        rm.rank <= 5 OR rm.production_year > 2010
    ORDER BY 
        rm.production_year DESC, rm.title
)

SELECT 
    vm.movie_id,
    vm.title,
    vm.actor_name,
    COALESCE(vm.keyword, 'No Keywords') AS movie_keywords,
    CASE 
        WHEN vm.production_year < 1970 THEN 'Classic'
        WHEN vm.production_year BETWEEN 1970 AND 1999 THEN 'Modern Classic'
        ELSE 'Recent'
    END AS era
FROM 
    ValidMovies vm
WHERE 
    vm.actor_name IS NOT NULL
ORDER BY 
    vm.production_year DESC, vm.title;
