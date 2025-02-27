WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(A.Id) AS AnswerCount,
        SUM(V.VoteTypeId = 2) - SUM(V.VoteTypeId = 3) AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 -- Questions
        AND P.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName
),
RecentActivePosts AS (
    SELECT 
        P.Id, 
        P.Title, 
        MAX(C.CreationDate) AS LatestCommentDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.AnswerCount,
    RP.NetVotes,
    RAP.LatestCommentDate,
    CASE 
        WHEN RAP.LatestCommentDate IS NULL THEN 'No Comments'
        WHEN RAP.LatestCommentDate < NOW() - INTERVAL '30 DAY' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentActivePosts RAP ON RP.PostId = RAP.Id
WHERE 
    RP.rn = 1
ORDER BY 
    RP.NetVotes DESC 
LIMIT 10;

-- Add a UNION ALL to combine with additional results
UNION ALL

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    0 AS AnswerCount,
    0 AS NetVotes,
    NULL AS LatestCommentDate,
    'New Post' AS ActivityStatus 
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id 
WHERE 
    P.PostTypeId = 1 
    AND P.CreationDate >= NOW() - INTERVAL '1 WEEK'
ORDER BY 
    P.CreationDate DESC 
LIMIT 5;
