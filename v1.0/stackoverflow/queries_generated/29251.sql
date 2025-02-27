WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- considering only questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.OwnerUserId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT bp.PostId) AS TotalPosts,
        SUM(bp.Score) AS TotalScore,
        SUM(bp.ViewCount) AS TotalViews,
        SUM(bp.AnswerCount) AS TotalAnswers,
        SUM(bp.CommentCount) AS TotalComments,
        STRING_AGG(DISTINCT bp.TagList, '; ') AS TagsUsed
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts bp ON u.Id = bp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserRankings AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.TotalPosts,
        um.TotalScore,
        um.TotalViews,
        um.TotalAnswers,
        um.TotalComments,
        um.TagsUsed,
        RANK() OVER (ORDER BY um.TotalScore DESC) AS ScoreRank
    FROM 
        UserMetrics um
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.TotalPosts,
    ur.TotalScore,
    ur.TotalViews,
    ur.TotalAnswers,
    ur.TotalComments,
    ur.TagsUsed,
    ur.ScoreRank
FROM 
    UserRankings ur
WHERE 
    ur.TotalPosts > 0
ORDER BY 
    ur.ScoreRank;

This SQL query benchmarks string processing by aggregating tags used by users in their posts and generating a ranking based on total score from their questions. It highlights users' activity and provides insight into their contributions along with the tag usage, creating an engaging analysis of user performance in a Stack Overflow-like system.
