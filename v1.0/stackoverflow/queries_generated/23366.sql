WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.Score > 0
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
AggregateTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
),
TopTagPosts AS (
    SELECT 
        TagName,
        ARRAY_AGG(PostId) AS PostIds
    FROM 
        AggregateTags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    tt.TagName AS PopularTag,
    CASE 
        WHEN pv.UpVotes > pv.DownVotes THEN 'Positive'
        WHEN pv.UpVotes < pv.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN rp.CreationDate IS NOT NULL THEN 
            CASE 
                WHEN rp.CreationDate < NOW() - INTERVAL '1 month' THEN 'Older'
                ELSE 'Recent'
            END
        ELSE 'Unknown'
    END AS PostAgeCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    TopTagPosts tt ON tt.PostIds @> ARRAY[rp.PostId]
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
