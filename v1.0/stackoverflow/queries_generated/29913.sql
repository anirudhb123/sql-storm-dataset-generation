WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerDisplayName,
        JSON_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerDisplayName ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.OwnerDisplayName
), 
RecentActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.CreationDate > current_date - INTERVAL '1 year' -- Users created in the last year
    GROUP BY 
        u.DisplayName
), 
UserPostStatistics AS (
    SELECT 
        r.OwnerDisplayName,
        COUNT(r.PostId) AS TotalPosts,
        AVG(r.ViewCount) AS AvgViews,
        SUM(r.AnswerCount) AS TotalAnswers,
        SUM(r.CommentCount) AS TotalComments,
        u.CommentCount AS UserComments,
        u.VoteCount AS UserVotes,
        u.BadgeCount AS UserBadges
    FROM 
        RankedPosts r
    JOIN 
        RecentActivity u ON r.OwnerDisplayName = u.DisplayName
    GROUP BY 
        r.OwnerDisplayName
)
SELECT 
    ups.OwnerDisplayName,
    ups.TotalPosts,
    ups.AvgViews,
    ups.TotalAnswers,
    ups.TotalComments,
    ups.UserComments,
    ups.UserVotes,
    ups.UserBadges
FROM 
    UserPostStatistics ups
ORDER BY 
    ups.TotalPosts DESC, ups.AvgViews DESC
LIMIT 10; -- Top 10 users by total posts and average views
