WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
TopTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        Tag
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    tt.Tag,
    tt.PostCount
FROM 
    FilteredPosts fp
JOIN 
    TopTags tt ON tt.Tag IN (SELECT unnest(string_to_array(substring(fp.Tags, 2, length(fp.Tags) - 2), '><')))
ORDER BY 
    fp.UpVotes DESC, 
    fp.CommentCount DESC;
