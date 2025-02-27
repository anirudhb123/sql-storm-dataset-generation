WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        U.DisplayName AS Author, 
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes V ON p.Id = V.PostId
    LEFT JOIN 
        Comments C ON p.Id = C.PostId
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        PostHistory PH ON p.Id = PH.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Only questions and answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, U.DisplayName
),
RankedPosts AS (
    SELECT 
        PS.*, 
        ROW_NUMBER() OVER (ORDER BY UpVotes DESC) AS VoteRank,
        ROW_NUMBER() OVER (ORDER BY CreationDate DESC) AS RecentRank
    FROM 
        PostStatistics PS
)
SELECT 
    PostId, 
    Title, 
    Author, 
    UpVotes, 
    DownVotes, 
    CommentCount, 
    BadgeCount, 
    CloseReopenCount, 
    VoteRank, 
    RecentRank
FROM 
    RankedPosts
WHERE 
    VoteRank <= 10 OR RecentRank <= 10
ORDER BY 
    VoteRank, RecentRank;
