WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Body,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '>')) AS tag_name ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1 -- only Questions
    GROUP BY 
        p.Id, u.DisplayName
), RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Body,
        rp.TagsArray,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 latest posts per user
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Body,
    rp.TagsArray,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE(STRING_AGG(DISTINCT bh.Name, ', '), 'No badges') AS UserBadges
FROM 
    RecentPosts rp
LEFT JOIN 
    Badges b ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
LEFT JOIN 
    Badges bh ON b.UserId = bh.UserId
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.OwnerDisplayName, rp.Body, rp.TagsArray, rp.CommentCount, rp.UpVotes, rp.DownVotes
ORDER BY 
    rp.CreationDate DESC;
