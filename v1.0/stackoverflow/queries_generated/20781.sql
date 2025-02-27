WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        p.Score, 
        p.ViewCount, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
PostWithBestAnswer AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        (SELECT 
            a.Id 
         FROM 
            Posts a 
         WHERE 
            a.ParentId = rp.PostId AND 
            a.PostTypeId = 2 
         ORDER BY 
            a.Score DESC, a.CreationDate ASC 
         LIMIT 1) AS BestAnswerId
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        ph.CreationDate AS HistoryDate, 
        p.Title AS PostTitle, 
        CASE 
            WHEN ph.Comment IS NULL THEN 'No Comment' 
            ELSE ph.Comment 
        END AS UserComment,
        ph.UserId,
        u.DisplayName AS EditorName
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.CreationDate >= (SELECT DATEADD(month, -3, GETDATE())) -- Last 3 months
)
SELECT 
    pwba.PostId, 
    pwba.Title AS QuestionTitle, 
    pwba.CreationDate AS QuestionCreationDate,
    pwba.Score AS QuestionScore,
    pwba.ViewCount AS QuestionViewCount,
    pwba.UpVotes AS QuestionUpVotes,
    pwba.DownVotes AS QuestionDownVotes,
    pwba.BestAnswerId,
    phd.HistoryDate, 
    phd.UserComment,
    phd.EditorName
FROM 
    PostWithBestAnswer pwba
LEFT JOIN 
    PostHistoryDetails phd ON pwba.PostId = phd.PostId
WHERE 
    (phd.PostHistoryTypeId IS NULL OR 
     phd.PostHistoryTypeId IN (1, 4, 24)) -- Specific types of changes
ORDER BY 
    pwba.Score DESC, 
    pwba.CreationDate ASC, 
    phd.HistoryDate DESC
OPTION (MAXRECURSION 0);
