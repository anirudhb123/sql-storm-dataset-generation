WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROUND(COALESCE((SELECT SUM(V.BountyAmount) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 8), 0) / NULLIF(COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0), 2) AS AvgBountyPerUpvote
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1
        AND P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.Score,
        PD.ViewCount,
        PD.CreationDate,
        PD.OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY PD.Score DESC, PD.ViewCount DESC) AS Rank
    FROM 
        PostDetails PD
    WHERE 
        PD.Score > 10
)
SELECT 
    PP.Title,
    PP.Score,
    PP.ViewCount,
    PP.CreationDate,
    PP.OwnerDisplayName,
    COALESCE(SUM(B.Id), 0) AS TotalBadges,
    COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalCloseVotes,
    PP.AvgBountyPerUpvote
FROM 
    PopularPosts PP
LEFT JOIN 
    Badges B ON PP.OwnerUserId = B.UserId
LEFT JOIN 
    PostHistory PH ON PP.PostId = PH.PostId
WHERE 
    PP.Rank <= 10
GROUP BY 
    PP.PostId, PP.Title, PP.Score, PP.ViewCount, PP.CreationDate, PP.OwnerDisplayName, PP.AvgBountyPerUpvote
ORDER BY 
    PP.Score DESC, PP.ViewCount DESC;
