WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only considering questions
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
HighlightedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        ts.PostCount
    FROM 
        RankedPosts rp
    JOIN 
        TagStatistics ts ON ts.Tag = ANY(string_to_array(rp.Tags, '><'))
    WHERE 
        rp.Rank <= 5 -- Get top 5 most recent questions per tag
    ORDER BY 
        ts.PostCount DESC
)
SELECT 
    h.PostId,
    h.Title,
    h.OwnerDisplayName,
    h.PostCount,
    COALESCE(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2::smallint), 0) AS UpVoteCount,
    COALESCE(SUM(v.VoteTypeId = 3::smallint), 0) AS DownVoteCount
FROM 
    HighlightedPosts h
LEFT JOIN 
    Comments c ON c.PostId = h.PostId
LEFT JOIN 
    Votes v ON v.PostId = h.PostId
GROUP BY 
    h.PostId, h.Title, h.OwnerDisplayName, h.PostCount
ORDER BY 
    h.PostCount DESC, UpVoteCount DESC;
