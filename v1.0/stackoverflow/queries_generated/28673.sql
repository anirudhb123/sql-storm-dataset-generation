WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount, -- Count of upvotes
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount, -- Count of downvotes
        ARRAY_AGG(DISTINCT t.TagName) AS Tags, -- Aggregate unique tags
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags FROM 2 FOR length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 AND -- Get top 5 questions by score for each user
        rp.Score >= 10 -- Only include high scored questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.BadgeCount,
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.Tags
FROM 
    UserReputation up
JOIN 
    FilteredPosts fp ON up.UserId = p.OwnerUserId
ORDER BY 
    up.Reputation DESC, 
    fp.Score DESC
LIMIT 50; -- Limit the output to the top 50 users and their posts
