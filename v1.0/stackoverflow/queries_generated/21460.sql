WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostsWithTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        SPLIT_PART(P.Tags, '><', 1) AS PrimaryTag,
        COALESCE(NULLIF(P.ViewCount, 0), 1) AS NonZeroViewCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts P
    WHERE 
        P.CreationDate > '2023-01-01'
),
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        COUNT(C.Comment) AS CommentCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId IN (2, 3)) AS VoteCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
Benchmark AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.BadgeCount,
        COUNT(P.PostId) AS PostCount,
        SUM(RP.VoteCount) AS TotalVotes,
        SUM(RP.CommentCount) AS TotalComments,
        COUNT(DISTINCT RT.Tag) AS UniqueTags,
        AVG(RP.NonZeroViewCount) AS AvgViews,
        ROW_NUMBER() OVER (PARTITION BY U.UserId ORDER BY COUNT(P.PostId) DESC) AS Rank
    FROM 
        UserBadges U
    LEFT JOIN 
        PostsWithTags P ON U.UserId = P.OwnerUserId
    LEFT JOIN 
        RecentPostActivity RP ON P.PostId = RP.PostId
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(P.PrimaryTag, ' ') AS RT ON TRUE
    GROUP BY 
        U.UserId, U.DisplayName, U.BadgeCount
    HAVING 
        AVG(RP.NonZeroViewCount) > 10 OR COUNT(P.PostId) > 5
)
SELECT 
    B.*,
    CASE 
        WHEN B.TotalVotes > 50 THEN 'Active Contributor'
        WHEN B.TotalComments > 20 THEN 'Comment Warrior'
        ELSE 'New Contributor'
    END AS ContributorType,
    CASE 
        WHEN B.PostCount > 10 THEN 'Frequent Poster'
        ELSE 'Occasional Poster'
    END AS PostingFrequency
FROM 
    Benchmark B
WHERE 
    EXISTS (SELECT 1 FROM Badges WHERE UserId = B.UserId AND Class = 1)
ORDER BY 
    B.Rank, B.PostCount DESC, B.TotalVotes DESC;
