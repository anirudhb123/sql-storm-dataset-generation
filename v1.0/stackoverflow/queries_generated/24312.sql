WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COALESCE(B.Name, 'No Badge') AS BadgeName,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            WHEN P.AnswerCount > 0 THEN 'Has Answers'
            ELSE 'No Answers'
        END AS AnswerStatus
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    LEFT JOIN 
        Badges B ON B.UserId = P.OwnerUserId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, B.Name
),
RecommendedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.Rank,
        RP.BadgeName,
        RP.AnswerStatus,
        (
            SELECT 
                COUNT(*) 
            FROM 
                PostLinks PL 
            WHERE 
                PL.PostId = RP.PostId 
                AND PL.LinkTypeId = 3 -- Duplicate
        ) AS DuplicateCount
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 10
)
SELECT 
    R.PostId,
    R.Title,
    R.Score,
    R.ViewCount,
    R.BadgeName,
    R.AnswerStatus,
    CASE 
        WHEN R.DuplicateCount > 0 THEN 'Duplicate' 
        ELSE 'Unique' 
    END AS PostType,
    COALESCE((SELECT AVG(CreationDate - LastEditDate) 
              FROM Posts 
              WHERE OwnerUserId = R.PostId 
              AND LastEditDate IS NOT NULL), 'No Edits') AS AvgEditTime
FROM 
    RecommendedPosts R
WHERE 
    R.ViewCount > (
        SELECT 
            AVG(ViewCount) 
        FROM 
            Posts 
        WHERE 
            CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    )
ORDER BY 
    R.Score DESC, 
    R.ViewCount DESC;

This query includes:
1. A Common Table Expression (CTE) `RankedPosts` to rank posts based on score, aggregate votes, and derive status.
2. A second CTE `RecommendedPosts` for filtering top-ranked posts and counting duplicates.
3. A final selection incorporating filtering logic and average calculations.
4. Use of correlated subqueries and COALESCE for managing NULLs and ensuring meaningful outputs.
5. Complicated predicates and expressions to assess the status and uniqueness of posts based on various conditions.
