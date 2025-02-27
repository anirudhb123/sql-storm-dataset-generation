WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
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
        p.Id, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 AND 
        rp.UniqueVoters > 10 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerName,
    fp.CommentCount,
    fp.UniqueVoters,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    LATERAL (
        SELECT 
            TRIM(UNNEST(STRING_TO_ARRAY(fp.Tags, '><'))) AS TagName
    ) AS t ON TRUE
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerName, fp.CommentCount, fp.UniqueVoters
ORDER BY 
    fp.UniqueVoters DESC, 
    fp.CommentCount DESC;
