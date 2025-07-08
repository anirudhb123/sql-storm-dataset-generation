
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR, p.CreationDate) ORDER BY COUNT(v.Id) DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag.VALUE = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ph.UserDisplayName AS CloserDisplayName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name = 'Post Closed'
)

SELECT 
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.VoteCount,
    rp.TagsArray,
    clp.CloseReason,
    clp.CloserDisplayName,
    rp.PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts clp ON rp.PostId = clp.PostId
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.CreationDate DESC;
