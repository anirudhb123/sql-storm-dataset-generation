WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(v.Id) DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId, u.DisplayName
),
FrequentTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        RankedPosts
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName
    FROM 
        FrequentTags
    WHERE 
        TagFrequency > 10 -- Only considering tags with more than 10 questions
),
FilteredRankedPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    JOIN 
        TopTags tt ON rp.Tags ILIKE '%' || tt.TagName || '%'
)
SELECT 
    frp.PostId,
    frp.Title,
    frp.OwnerDisplayName,
    frp.CommentCount,
    frp.UpVotes,
    frp.DownVotes,
    frp.Tags
FROM 
    FilteredRankedPosts frp
WHERE 
    frp.TagRank <= 5 -- Get top 5 posts per tag
ORDER BY 
    frp.TagRank, frp.UpVotes DESC;
