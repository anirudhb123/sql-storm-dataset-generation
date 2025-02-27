WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(b.Count, 0) AS BadgeCount,
        COALESCE(votes.VoteCount, 0) AS VoteCount,
        array_agg(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount
         FROM Votes
         GROUP BY PostId) AS votes ON votes.PostId = p.Id
    LEFT JOIN 
        (SELECT PostId, TagName 
         FROM Posts 
         CROSS JOIN LATERAL unnest(string_to_array(Tags, '>')) AS TagName) AS t ON t.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, u.DisplayName, b.Count, votes.VoteCount
), FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        Score, 
        OwnerDisplayName,
        BadgeCount,
        VoteCount,
        Tags,
        UserPostRank
    FROM 
        RankedPosts
    WHERE 
        UserPostRank <= 5 -- Limited to top 5 posts per user
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.Score,
    fp.OwnerDisplayName,
    fp.BadgeCount,
    fp.VoteCount,
    fp.Tags,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fp.PostId) AS CommentCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate DESC
LIMIT 10; -- Limit to top 10 posts in terms of score
