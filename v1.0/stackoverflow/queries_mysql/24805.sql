
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        @row_number := IF(@prev_post_type_id = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type_id := p.PostTypeId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%'),
        (SELECT @row_number := 0, @prev_post_type_id := NULL) AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 AND
        rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts) AND
        EXISTS (
            SELECT 1 
            FROM Comments c 
            WHERE c.PostId = rp.PostId 
            AND c.CreationDate >= NOW() - INTERVAL 6 MONTH
        )
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Rank,
    CASE 
        WHEN fp.ViewCount IS NULL THEN 'No views recorded'
        ELSE CAST(fp.ViewCount AS CHAR)
    END AS ViewCountDisplay,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT 
        COALESCE(SUM(v.BountyAmount), 0)
        FROM Votes v 
        WHERE v.PostId = fp.PostId AND v.VoteTypeId IN (8, 9)
    ) AS TotalBountyAmount,
    fp.Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
WHERE 
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = fp.PostId AND ph.PostHistoryTypeId IN (10, 11)) > 1
ORDER BY 
    fp.Rank;
