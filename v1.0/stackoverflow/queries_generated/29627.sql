WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        MAX(p.CreationDate) AS LastActivity,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.LastActivity
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5  -- Top 5 posts for each tag
),
PostTagCounts AS (
    SELECT 
        t.TagName,
        COUNT(tp.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])  -- Extracting tags
    JOIN 
        TopPosts tp ON tp.PostId = p.Id
    GROUP BY 
        t.TagName
),
BadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.LastActivity,
    t.PostCount AS TagPostCount,
    bc.BadgeCount
FROM 
    TopPosts tp
JOIN 
    PostTagCounts t ON t.TagName = ANY(string_to_array(substring(tp.Tags, 2, length(tp.Tags) - 2), '><'))  -- Assuming Tags field is available in TopPosts
JOIN 
    BadgeCounts bc ON bc.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    tp.CommentCount DESC, tp.LastActivity DESC;
