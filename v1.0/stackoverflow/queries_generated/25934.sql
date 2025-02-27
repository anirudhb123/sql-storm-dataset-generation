WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.AcceptedAnswerId,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' -- Filter to include posts created in 2022 onward
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.AcceptedAnswerId, ph.PostHistoryTypeId
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    tt.Tag AS MostPopularTag,
    tt.PostCount AS TagPostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON rp.Tags LIKE '%' || tt.Tag || '%'
WHERE 
    rp.rn = 1  -- Get the latest revision for each post
ORDER BY 
    rp.UpVotes DESC, rp.CreationDate DESC
LIMIT 100; -- Limit to top 100 posts
