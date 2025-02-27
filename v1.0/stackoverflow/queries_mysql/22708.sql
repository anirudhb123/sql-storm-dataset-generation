
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank,
        COALESCE(PH.UserId, -1) AS LastEditorId,
        PH.CreationDate AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6) 
    WHERE 
        P.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS Tag,
        COUNT(*) AS TagUsage
    FROM 
        Posts CROSS JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
    ORDER BY 
        TagUsage DESC
    LIMIT 20
),
PostMetrics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.Score,
        RP.Rank,
        US.Reputation,
        COALESCE(UT.UserId, -1) AS TopVoterId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        CASE 
            WHEN RP.Score >= 10 THEN 'Highly Engaging'
            WHEN RP.Score BETWEEN 5 AND 9 THEN 'Moderately Engaging'
            ELSE 'Low Engagement'
        END AS EngagementLevel,
        GROUP_CONCAT(DISTINCT PT.Name) AS PostHistoryTypes
    FROM 
        RankedPosts RP
    JOIN 
        UserStats US ON RP.LastEditorId = US.UserId
    LEFT JOIN 
        Comments C ON RP.PostId = C.PostId
    LEFT JOIN 
        Votes V ON RP.PostId = V.PostId
    LEFT JOIN 
        PostHistoryTypes PT ON V.VoteTypeId = PT.Id
    LEFT JOIN 
        (SELECT 
            PostId,
            MAX(UserId) AS UserId 
        FROM 
            Votes 
        WHERE 
            VoteTypeId IN (2, 3) 
        GROUP BY 
            PostId) UT ON RP.PostId = UT.PostId
    GROUP BY 
        RP.PostId, RP.Title, RP.ViewCount, RP.Score, RP.Rank, US.Reputation, UT.UserId
)
SELECT 
    PM.PostId,
    PM.Title,
    PM.ViewCount,
    PM.Score,
    PM.Rank,
    PM.Reputation,
    PM.CommentCount,
    PM.EngagementLevel,
    (SELECT GROUP_CONCAT(Tag SEPARATOR ', ') FROM PopularTags) AS PopularTags,
    CASE 
        WHEN PM.Reputation IS NULL THEN 'No Reputation'
        WHEN PM.Reputation >= 1000 THEN 'Veteran User'
        ELSE 'Newbie User'
    END AS UserExperienceLevel,
    NULLIF(PM.TopVoterId, -1) AS TopVoter
FROM 
    PostMetrics PM
WHERE 
    PM.Rank <= 10
ORDER BY 
    PM.Score DESC, PM.ViewCount DESC;
