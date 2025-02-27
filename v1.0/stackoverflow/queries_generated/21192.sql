WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
        AND P.Score IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostDetails AS (
    SELECT 
        FP.Title,
        FP.OwnerDisplayName,
        COALESCE(CH.CommentCount, 0) AS CommentCount,
        COALESCE(A.AnswerCount, 0) AS AnswerCount,
        FP.Score,
        FP.ViewCount,
        CASE 
            WHEN FP.Score > 0 THEN 'Positive'
            WHEN FP.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreSentiment
    FROM 
        FilteredPosts FP
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2
        GROUP BY 
            PostId
    ) A ON FP.PostId = A.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) CH ON FP.PostId = CH.PostId
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    PD.Title,
    PD.OwnerDisplayName,
    PD.CommentCount,
    PD.AnswerCount,
    PD.Score AS PostScore,
    PD.ViewCount,
    PVS.TotalUpvotes,
    PVS.TotalDownvotes,
    (PD.Score + COALESCE(PVS.TotalUpvotes, 0) - COALESCE(PVS.TotalDownvotes, 0)) AS NetScore,
    CASE 
        WHEN PD.ViewCount > 1000 THEN 'Highly Viewed'
        WHEN PD.ViewCount BETWEEN 500 AND 1000 THEN 'Moderately Viewed'
        ELSE 'Less Viewed'
    END AS ViewCategory
FROM 
    PostDetails PD
LEFT JOIN 
    PostVoteSummary PVS ON PD.PostId = PVS.PostId
ORDER BY 
    NetScore DESC,
    PD.CommentCount DESC
LIMIT 50;

-- Additional insights regarding posts with higher engagement metrics
WITH EngagementStats AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        (COALESCE(COUNT(C.Id), 0) + COALESCE(COUNT(V.Id), 0)) AS EngagementCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        P.Id
)
SELECT 
    E.PostId,
    E.EngagementCount,
    CASE 
        WHEN E.EngagementCount > 50 THEN 'Highly Engaged' 
        ELSE 'Less Engaged' 
    END AS EngagementCategory
FROM 
    EngagementStats E
WHERE 
    E.Score > 10
ORDER BY 
    E.EngagementCount DESC;
