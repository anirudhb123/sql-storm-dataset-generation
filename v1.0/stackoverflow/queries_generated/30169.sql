WITH RankedQuestions AS (
    SELECT 
        Q.Id AS QuestionId,
        Q.Title,
        Q.CreationDate,
        Q.ViewCount,
        Q.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM Q.CreationDate) ORDER BY Q.ViewCount DESC) AS Rank
    FROM 
        Posts AS Q
    JOIN 
        Users AS U ON Q.OwnerUserId = U.Id
    WHERE 
        Q.PostTypeId = 1 -- Selecting only questions
        AND Q.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
),
CloseVotes AS (
    SELECT 
        PH.PostId,
        PH.Comment,
        PH.CreationDate AS CloseDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS VoteCount
    FROM 
        PostHistory AS PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
),
TopBadgedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users AS U
    LEFT JOIN 
        Badges AS B ON U.Id = B.UserId
    GROUP BY 
        U.Id
    HAVING 
        COUNT(B.Id) > 5
),
RecentActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.LastActivityDate,
        P.AnswerCount,
        P.CommentCount,
        P.ViewCount,
        R.OwnerDisplayName,
        COALESCE(CV.CloseCount, 0) AS CloseCount
    FROM 
        Posts AS P
    LEFT JOIN 
        RankedQuestions AS R ON P.Id = R.QuestionId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CloseCount 
        FROM 
            CloseVotes 
        GROUP BY 
            PostId
    ) AS CV ON P.Id = CV.PostId
    WHERE 
        P.LastActivityDate >= NOW() - INTERVAL '30 days' -- Posts active in the last 30 days
        AND P.PostTypeId IN (1, 2) -- Questions and Answers
)
SELECT 
    RA.Title,
    RA.ViewCount,
    RA.OwnerDisplayName,
    COALESCE(BU.BadgeCount, 0) AS BadgeCount,
    RA.CloseCount,
    CASE 
        WHEN RA.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RecentActivePosts AS RA
LEFT JOIN 
    TopBadgedUsers AS BU ON RA.OwnerUserId = BU.UserId
ORDER BY 
    RA.ViewCount DESC, RA.LastActivityDate DESC
LIMIT 100;
