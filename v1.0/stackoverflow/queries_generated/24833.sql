WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS Author,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS ScoreRank,
        COALESCE(V.UpVotes, 0) - COALESCE(V.DownVotes, 0) AS NetVotes,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes
         GROUP BY 
            PostId) V ON P.Id = V.PostId
),

FilteredPosts AS (
    SELECT 
        RP.*,
        T.TagName,
        ROW_NUMBER() OVER (PARTITION BY RP.PostId ORDER BY RP.ViewCount DESC) as TagRank
    FROM 
        RankedPosts RP
    LEFT JOIN 
        (SELECT 
            PostId, 
            STRING_AGG(TagName, ', ') AS TagName
         FROM 
            Posts,
            UNNEST(string_to_array(Tags, ',')) AS TagName
         GROUP BY 
            PostId) T ON RP.PostId = T.PostId
    WHERE 
        RP.ViewCount >= (SELECT AVG(ViewCount) FROM Posts)  -- Filter for posts above average views
)

SELECT 
    FP.PostId,
    FP.Title,
    FP.CreationDate,
    FP.ViewCount,
    FP.Score,
    FP.Author,
    FP.NetVotes,
    FP.AnswerStatus,
    CASE 
        WHEN FP.TagRank = 1 THEN 'Primary Tag'
        ELSE NULL
    END AS PrimaryTagIndicator
FROM 
    FilteredPosts FP
WHERE 
    (FP.Score >= 10 OR FP.NetVotes > 5)  -- For high-scoring or heavily upvoted posts
    AND FP.AnswerStatus = 'Accepted'
ORDER BY 
    FP.Score DESC, FP.CreationDate ASC;

-- JOIN additional tables to get PostHistory data
SELECT 
    FP.*,
    PHT.UserDisplayName AS LastEditor,
    PHT.CreationDate AS LastEditDate,
    PHT.Comment AS EditComment
FROM 
    (Previous SQL Result) AS FP
LEFT JOIN 
    PostHistory PHT ON FP.PostId = PHT.PostId AND PHT.PostHistoryTypeId IN (4, 5)  -- Title edit and Body edit
WHERE 
    PHT.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = FP.PostId)
    AND PHT.Comment IS NOT NULL;

-- Correlating with a complex subquery using different logic
WITH BadgedUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    WHERE 
        Class = 1  -- Gold badges
    GROUP BY 
        UserId
)

SELECT 
    FP.*,
    BU.BadgeCount
FROM 
    FilteredPosts FP
LEFT JOIN 
    BadgedUsers BU ON FP.Author = BU.UserId
WHERE 
    (BU.BadgeCount IS NULL OR BU.BadgeCount < 2)  -- Exclude users with 2 or more gold badges
ORDER BY 
    FP.CreationDate DESC;

-- Additional complexity: NULL handling with obscure conditions
SELECT 
    FP.*,
    CASE 
        WHEN FP.Score IS NULL THEN 'No Score'
        WHEN FP.Score <= 0 THEN 'Neutral Score'
        ELSE 'Positive Score'
    END AS ScoreCategory
FROM 
    (Previous SQL Result)
WHERE 
    (FP.ViewCount IS NOT NULL AND FP.ViewCount > 100)  -- Filter only posts with more than 100 views
ORDER BY 
    ScoreCategory, FP.Title;

