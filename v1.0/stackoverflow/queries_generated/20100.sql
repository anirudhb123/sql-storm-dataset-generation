WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Questions
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN vt.Name IN ('Close', 'Reopen') THEN 1 END) AS CloseVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.CloseVotes,
    ps.TotalVotes,
    COALESCE(pt.Tags, ARRAY['No Tags']) AS Tags,
    CASE 
        WHEN ps.TotalVotes = 0 THEN 'No Votes' 
        ELSE CASE 
            WHEN ps.UpVotes > ps.DownVotes THEN 'Positive'
            WHEN ps.UpVotes < ps.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END 
    END AS VoteSentiment,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Post' 
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    VoteSummary ps ON rp.PostId = ps.PostId
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    COALESCE(ps.CloseVotes, 0) < 2 -- Including only posts with fewer than 2 close votes
ORDER BY 
    rp.ViewCount DESC, 
    rp.Title ASC
OFFSET 3 LIMIT 10; -- Skipping the first 3 results in the ranked posts

This SQL query features several advanced constructs such as Common Table Expressions (CTEs), window functions, conditional aggregation, and NULL handling through COALESCE. Each component of the query serves to aggregate and analyze posts from the schema based on their popularity, voting trends, and tagging, demonstrating an intricate balancing of logic and SQL’s capabilities while addressing potential corner cases like posts without tags or votes.
