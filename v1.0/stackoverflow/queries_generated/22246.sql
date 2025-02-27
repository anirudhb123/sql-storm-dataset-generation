WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn,
        COALESCE(EXTRACT(DAY FROM age(p.CreationDate)) - p.AnswerCount, 0) AS DayScoreAdjustment
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
FilteredPosts AS (
    SELECT 
        rp.*,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.Id
    LEFT JOIN 
        Votes v ON v.PostId = rp.Id AND v.VoteTypeId IN (8, 9) -- Filter for Bounty votes
    GROUP BY 
        rp.Id, rp.Title, rp.Score, rp.ViewCount, rp.AnswerCount, rp.CreationDate, rp.rn, rp.DayScoreAdjustment
    HAVING 
        SUM(CASE WHEN c.Score IS NULL THEN 0 ELSE 1 END) > 5 -- Only posts with more than 5 comments
),
FinalPosts AS (
    SELECT 
        fp.*, 
        fp.Score + fp.DayScoreAdjustment + COALESCE(fp.TotalBounty, 0) AS EffectiveScore
    FROM 
        FilteredPosts fp
    WHERE 
        fp.rn = 1 -- Take only the top scored questions per user
)
SELECT 
    fp.Id, 
    fp.Title, 
    fp.EffectiveScore,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.Id AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.Id AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     JOIN LATERAL unnest(string_to_array(fp.Tags, ',')) AS tag ON t.TagName = tag) AS TagsList
FROM 
    FinalPosts fp
WHERE 
    EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = fp.Id AND ph.PostHistoryTypeId = 10) 
ORDER BY 
    EffectiveScore DESC
FETCH FIRST 10 ROWS ONLY;

