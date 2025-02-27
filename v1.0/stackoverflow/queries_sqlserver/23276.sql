
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        AVG(ISNULL(v.VoteTypeId, 0)) AS AverageVoteType,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tags_array
    LEFT JOIN 
        Tags t ON t.TagName = LTRIM(RTRIM(tags_array.value))
    WHERE 
        pt.Name IN ('Question', 'Answer')
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.Rank,
        rp.CommentCount,
        CASE 
            WHEN rp.AverageVoteType = 0 THEN 'No Votes'
            WHEN rp.AverageVoteType IS NULL THEN 'No Votes Recorded'
            ELSE 'Average Vote Type: ' + CAST(rp.AverageVoteType AS VARCHAR)
        END AS VoteDescription,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    u.DisplayName AS OwnerDisplayName,
    fp.CreationDate,
    fp.CommentCount,
    fp.VoteDescription,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
ORDER BY 
    fp.CommentCount DESC, fp.CreationDate DESC
OFFSET (SELECT COUNT(*) FROM FilteredPosts) / 2 ROWS
FETCH NEXT 10 ROWS ONLY;
