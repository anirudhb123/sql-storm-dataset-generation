WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
AggregatedTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        RankedPosts
),
TagCounts AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagFrequency
    FROM 
        AggregatedTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        TagFrequency,
        ROW_NUMBER() OVER (ORDER BY TagFrequency DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        TagFrequency > 5
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    te.Tag AS MostFrequentTag,
    pe.CommentCount,
    pe.UpVotes,
    pe.DownVotes
FROM 
    RankedPosts rp
JOIN 
    PostEngagement pe ON rp.PostId = pe.PostId
JOIN 
    TopTags te ON te.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.ViewCount DESC;
