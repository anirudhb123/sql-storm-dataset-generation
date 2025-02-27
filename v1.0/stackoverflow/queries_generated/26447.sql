WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive'
            WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 -- top 5 posts per tag
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.Tags,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.Sentiment
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC, 
    fp.ViewCount DESC;

