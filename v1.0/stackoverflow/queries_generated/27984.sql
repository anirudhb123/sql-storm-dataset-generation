WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Body,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,  -- UpMod votes
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount  -- DownMod votes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id
),
PostsWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.TagCount,
        rp.CommentCount,
        rb.BadgeName,
        rb.Class AS BadgeClass
    FROM 
        RankedPosts rp
    JOIN 
        Badges rb ON rb.UserId = p.OwnerUserId
    WHERE 
        rb.Class = 1  -- Only Gold badges for user recognition
),
BenchmarkMetrics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgScore,
        SUM(ViewCount) AS TotalViews,
        SUM(TagCount) AS TotalTags,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVoteCount) AS TotalUpVotes,
        SUM(DownVoteCount) AS TotalDownVotes,
        COUNT(DISTINCT BadgeName) AS UniqueBadges
    FROM 
        PostsWithBadges
)
SELECT 
    *,
    CASE 
        WHEN AvgScore > 50 THEN 'High Engagement'
        WHEN AvgScore BETWEEN 20 AND 50 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    BenchmarkMetrics;
