WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Questions only
        AND P.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        Owner
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
VoteSummary AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.ViewCount,
    TP.Score,
    TP.Owner,
    COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(VS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(VS.DownVotes, 0) AS TotalDownVotes
FROM 
    TopPosts TP
LEFT JOIN 
    UserBadges UB ON TP.Owner = UB.UserId
LEFT JOIN 
    VoteSummary VS ON TP.PostId = VS.PostId
ORDER BY 
    TP.Score DESC NULLS LAST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
