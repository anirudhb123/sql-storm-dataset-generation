WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS AuthorDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
ActiveBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostCloseReasons AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
),
UserVotes AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN V.VoteTypeId = 7 THEN 1 END) AS ReopenVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.AuthorDisplayName,
    COALESCE(AB.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(AB.BadgeNames, 'No Badges') AS UserBadgeNames,
    PCR.CloseReason,
    COALESCE(UV.UpVotes, 0) AS UserUpVotes,
    COALESCE(UV.DownVotes, 0) AS UserDownVotes
FROM 
    RankedPosts RP
LEFT JOIN 
    ActiveBadges AB ON RP.AuthorDisplayName = (SELECT DisplayName FROM Users WHERE Id = AB.UserId LIMIT 1)
LEFT JOIN 
    PostCloseReasons PCR ON RP.PostId = PCR.PostId
LEFT JOIN 
    UserVotes UV ON RP.PostId IN (SELECT PostId FROM Votes WHERE UserId = UV.UserId)
WHERE 
    RP.Rank = 1 -- Only select the latest post of each type
ORDER BY 
    RP.Score DESC,
    RP.Title COLLATE "C" -- Testing collations
LIMIT 50;
This SQL query utilizes several constructs, including CTEs, window functions, COALESCE for NULL handling, correlated subqueries, and complex joins. The query explores the latest posts from the past year, gathering additional data about authors, badges, close reasons, and votes, while demonstrating performance and complexity potential in a relational database query context.
