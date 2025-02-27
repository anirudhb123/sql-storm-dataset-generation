
WITH RankedPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        Users.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY Posts.PostTypeId ORDER BY Posts.Score DESC) AS Rank,
        COUNT(Comments.Id) AS TotalComments
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    WHERE 
        Posts.CreationDate > '2024-10-01 12:34:56' - INTERVAL 1 MONTH
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Posts.Score, Posts.ViewCount, Users.DisplayName
),
RecentVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes
    WHERE 
        CreationDate > '2024-10-01 12:34:56' - INTERVAL 1 MONTH
    GROUP BY 
        PostId
),
BadgesCount AS (
    SELECT 
        UserId,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
CombinedData AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        RV.Upvotes,
        RV.Downvotes,
        BC.GoldBadges,
        BC.SilverBadges,
        BC.BronzeBadges,
        RP.TotalComments,
        CASE 
            WHEN RP.Score > 100 THEN 'Highly Rated'
            WHEN RP.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
            ELSE 'Low Rated'
        END AS PostRating
    FROM 
        RankedPosts RP
    LEFT JOIN 
        RecentVotes RV ON RP.PostId = RV.PostId
    LEFT JOIN 
        BadgesCount BC ON RP.OwnerDisplayName = BC.UserId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    Upvotes,
    Downvotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalComments,
    PostRating
FROM 
    CombinedData
WHERE 
    (Upvotes - Downvotes) > 10 
    AND PostRating = 'Highly Rated'
ORDER BY 
    CreationDate DESC;
