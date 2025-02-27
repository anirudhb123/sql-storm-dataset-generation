WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(co.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerRank <= 5
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        unnest(string_to_array(p.Tags, ','))
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    pt.Tag
FROM 
    FilteredPosts fp
JOIN 
    PostTags pt ON fp.PostId = pt.PostId
JOIN 
    PopularTags ptg ON pt.Tag = ptg.Tag
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
