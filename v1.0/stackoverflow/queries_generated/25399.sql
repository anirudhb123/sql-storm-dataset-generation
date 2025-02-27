WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag
    JOIN 
        Tags t ON tag = t.TagName
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(c.Score) AS TotalCommentScore,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

CompetitiveResults AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.QuestionsCount,
        ua.AnswersCount,
        ua.TotalCommentScore,
        ua.TotalBadges,
        RP.Title,
        RP.CreationDate,
        RP.ViewCount,
        RP.CommentCount,
        RP.TagsArray,
        ROW_NUMBER() OVER (ORDER BY ua.TotalPosts DESC, ua.TotalCommentScore DESC) AS LeaderboardRank
    FROM 
        UserActivity ua
    JOIN 
        RankedPosts RP ON ua.UserId = RP.OwnerUserId
)

SELECT 
    cr.LeaderboardRank,
    cr.DisplayName,
    cr.TotalPosts,
    cr.QuestionsCount,
    cr.AnswersCount,
    cr.TotalCommentScore,
    cr.TotalBadges,
    cr.Title,
    cr.CreationDate,
    cr.ViewCount,
    cr.CommentCount,
    cr.TagsArray
FROM 
    CompetitiveResults cr
WHERE 
    cr.LeaderboardRank <= 10
ORDER BY 
    cr.LeaderboardRank;
