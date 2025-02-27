WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(UPV.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(DOWNV.DownvoteCount, 0) AS DownvoteCount,
        PH.UserDisplayName AS LastEditor,
        PH.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS UserRank
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS UpvoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2
        GROUP BY 
            PostId
    ) UPV ON P.Id = UPV.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS DownvoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 3
        GROUP BY 
            PostId
    ) DOWNV ON P.Id = DOWNV.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            UserDisplayName, 
            MAX(CreationDate) AS CreationDate
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5) -- Edit Title or Edit Body
        GROUP BY 
            PostId, UserDisplayName
    ) PH ON P.Id = PH.PostId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.Score) AS TotalScore,
        COUNT(P.Id) AS PostsCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName 
    HAVING 
        SUM(P.Score) > 1000
),
ActiveUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS ActivePosts
    FROM 
        Posts
    WHERE 
        CreationDate > NOW() - INTERVAL '1 month'
    GROUP BY 
        UserId
)
SELECT 
    P.PostId,
    P.Title,
    P.ViewCount,
    P.UpvoteCount,
    P.DownvoteCount,
    P.LastEditor,
    P.LastEditDate,
    U.DisplayName AS ActiveUser,
    AU.ActivePosts
FROM 
    PostStats P
LEFT JOIN 
    TopUsers U ON P.UserRank = 1
LEFT JOIN 
    ActiveUsers AU ON P.PostId = AU.UserId
WHERE 
    P.Score > 10
ORDER BY 
    P.Score DESC, P.ViewCount DESC;
