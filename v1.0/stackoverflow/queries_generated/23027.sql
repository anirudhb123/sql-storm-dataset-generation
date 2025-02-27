WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.PostTypeId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COALESCE(up_votes.UpVotes, 0) AS TotalUpVotes,
        COALESCE(down_votes.DownVotes, 0) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS UpVotes 
        FROM Votes 
        WHERE VoteTypeId = 2 
        GROUP BY PostId
    ) up_votes ON p.Id = up_votes.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS DownVotes 
        FROM Votes 
        WHERE VoteTypeId = 3 
        GROUP BY PostId
    ) down_votes ON p.Id = down_votes.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month' 
        AND p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
), PostDetail AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.TotalUpVotes,
        rp.TotalDownVotes,
        CASE 
            WHEN rp.ScoreRank = 1 THEN 'Top'
            WHEN rp.ScoreRank <= 5 THEN 'Top 5'
            ELSE 'Other'
        END AS ScoreCategory,
        (SELECT STRING_AGG(TagName, ', ') 
         FROM Tags t 
         WHERE t.Id IN (
            SELECT UNNEST(string_to_array(rp.Tags, '><'))::int 
            FROM Posts 
            WHERE Id = rp.PostId)
        ) AS TagList
    FROM 
        RankedPosts rp
), UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), PostHistoryRecords AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        STRING_AGG(CONCAT(COALESCE(u.DisplayName, 'Deleted User'), ': ', ph.Comment), '; ') AS UserComments
    FROM 
        PostHistory ph
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.CreationDate >= (CURRENT_DATE - INTERVAL '1 year') 
        AND ph.PostHistoryTypeId IN (10, 11, 12, 13)
    GROUP BY 
        ph.PostId, ph.UserId, ph.PostHistoryTypeId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.TotalUpVotes,
    pd.TotalDownVotes,
    pd.ScoreCategory,
    pd.TagList,
    ups.TotalPosts,
    ups.AcceptedAnswers,
    ph.ChangeCount,
    ph.UserComments
FROM 
    PostDetail pd
LEFT JOIN 
    UserPostStats ups ON pd.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ups.UserId)
LEFT JOIN 
    PostHistoryRecords ph ON pd.PostId = ph.PostId
WHERE 
    (pd.Score > 10 OR pd.ViewCount > 100) 
    AND (pd.TotalUpVotes - pd.TotalDownVotes) > 0
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 100;
