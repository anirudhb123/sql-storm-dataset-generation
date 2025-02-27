WITH TopTags AS (
    SELECT 
        TRIM(unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))) AS tag_name,
        COUNT(*) AS tag_count
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- We're interested in Question posts
    GROUP BY 
        tag_name
    ORDER BY 
        tag_count DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        p.Id AS post_id,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.upvote_count, 0) AS upvote_count,
        COALESCE(v.downvote_count, 0) AS downvote_count,
        COUNT(c.Id) AS comment_count,
        COUNT(bl.Id) AS badge_count,
        STRING_AGG(DISTINCT t.tag_name, ', ') AS associated_tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges bl ON p.OwnerUserId = bl.UserId
    LEFT JOIN 
        TopTags t ON t.tag_name = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
    WHERE 
        p.PostTypeId = 1  -- Getting data for Question posts
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.upvote_count DESC, ps.comment_count DESC) AS rank
    FROM 
        PostStatistics ps
)
SELECT 
    rp.post_id,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.upvote_count,
    rp.downvote_count,
    rp.comment_count,
    rp.badge_count,
    rp.associated_tags,
    rp.rank
FROM 
    RankedPosts rp
WHERE 
    rp.rank <= 10  -- Get top 10 ranked posts
ORDER BY 
    rp.rank;
