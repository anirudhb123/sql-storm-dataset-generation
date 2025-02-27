WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter posts created in the last year
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
), 
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
TagUsage AS (
    SELECT 
        Tag,
        COUNT(PostId) AS TagCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10 -- Top 10 tags used
),
TopPosts AS (
    SELECT 
        rp.*,
        STRING_AGG(t.Tag, ', ') AS UsedTags
    FROM 
        RankedPosts rp
    JOIN 
        PostTagCounts pt ON rp.PostId = pt.PostId
    JOIN 
        TagUsage t ON pt.Tag = t.Tag
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.OwnerDisplayName, rp.OwnerReputation, rp.VoteRank
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.VoteCount,
    tp.VoteRank,
    tp.UsedTags
FROM 
    TopPosts tp
WHERE 
    tp.VoteRank <= 5 -- Get the top 5 most voted posts
ORDER BY 
    tp.VoteCount DESC;
